// KMusic NDJSON provider process. Protocol and lifecycle adapter are KMusic code.
// API modules/core below are attributed AGPL SPlayer Next code (netease/NOTICE.md).
import { createInterface } from "node:readline";
import { createRequest } from "./netease/core/request.ts";
import cloudsearch from "./netease/modules/cloudsearch.ts";
import songDetail from "./netease/modules/song_detail.ts";
import songUrl from "./netease/modules/song_url.ts";
import lyric from "./netease/modules/lyric_new.ts";
import albumNew from "./netease/modules/album_new.ts";
import album from "./netease/modules/album.ts";
import playlist from "./netease/modules/playlist_detail.ts";

import qrKey from "./netease/modules/login_qr_key.ts";
import qrCheck from "./netease/modules/login_qr_check.ts";
import loginStatus from "./netease/modules/login_status.ts";
import logout from "./netease/modules/logout.ts";
import { cookieToJson } from "./netease/core/cookie.ts";

// Credentials stay in memory here and cross only the private parent/child pipe.
let session: Record<string, string> = {};
let authEpoch = 0;
function mergeCookies(lines: string[]) {
  for (const line of lines) Object.assign(session, cookieToJson(line.split(";")[0]));
}
function sessionString() { return Object.entries(session).map(([k,v]) => `${k}=${v}`).join("; "); }
const modules = { search: cloudsearch, detail: songDetail, lyric, album, playlist, newAlbums: albumNew };
const input = createInterface({ input: process.stdin, crlfDelay: Infinity });
const emit = (data: unknown) => process.stdout.write(JSON.stringify(data) + "\n");
input.on("line", async (line) => {
  if (line.length > 32768) return;
  let id: number | string = "";
  try {
    const req = JSON.parse(line);
    id = req.id;
    const params = { ...(req.params ?? {}), cookie: { ...session } };
    if (req.action === "sessionRestore") {
      ++authEpoch; session = cookieToJson(String(req.params?.cookie || ""));
      emit({ id, ok: true }); return;
    }
    if (req.action === "logout") {
      ++authEpoch; session = {};
      // Local logout is immediate even when the remote endpoint is unavailable.
      try { await logout(params, createRequest); } catch {}
      emit({ id, ok: true }); return;
    }
    if (req.action === "qrKey") {
      const response = await qrKey(params, createRequest);
      const body: any = response.body;
      const key = body.data?.unikey;
      if (!key) throw new Error("NetEase did not return a login key");
      emit({ id, ok: true, body: { key } }); return;
    }
    if (req.action === "qrCheck") {
      const epoch = authEpoch;
      const response = await qrCheck(params, createRequest);
      const body: any = response.body;
      if (epoch !== authEpoch) { emit({ id, ok: false, message: "Login cancelled" }); return; }
      if (Number(body.code) === 803) {
        mergeCookies(response.cookie);
        if (!session.MUSIC_U) throw new Error("Login confirmed without an account session");
      }
      emit({ id, ok: true, body: { code: Number(body.code), sessionCookie: Number(body.code) === 803 ? sessionString() : undefined } }); return;
    }
    if (req.action === "accountStatus") {
      const response = await loginStatus(params, createRequest);
      const body: any = response.body;
      const profile = body.data?.profile ?? body.profile;
      const account = body.data?.account ?? body.account;
      emit({ id, ok: true, body: { authenticated: Boolean(account?.id && profile?.userId), nickname: profile?.nickname || "", userId: String(profile?.userId || "") } }); return;
    }
    if (req.action === "resolve") {
      const details = await songDetail({ cookie: params.cookie, ids: String(params.songId) }, createRequest);
      const response = await songUrl({ cookie: params.cookie, id: String(params.songId), level: params.level || "standard" }, createRequest);
      const body: any = response.body;
      const item = body.data?.[0];
      if (!item?.url) {
        emit({ id, ok: false, category: body.code === 301 || body.code === 401 ? "auth" : "unavailable", message: "NetEase returned no playable URL (account or rights required)", code: body.code });
        return;
      }
      emit({ id, ok: true, body: { song: (details.body as any).songs?.[0], url: item.url, trial: Boolean(item.freeTrialInfo), trialInfo: item.freeTrialInfo ?? null, level: item.level, bitrate: item.br } });
      return;
    }
    const mod = modules[req.action as keyof typeof modules];
    if (!mod) throw new Error("Unsupported provider action");
    const response = await mod(params, createRequest);
    const body: any = response.body;
    if (body.code === 301 || body.code === 401 || body.code === -460) {
      emit({ id, ok: false, category: "auth", sessionExpired: Boolean(session.MUSIC_U) && [301,401].includes(Number(body.code)), message: "NetEase login is required or expired", code: body.code });
    } else if (body.code && body.code !== 200) {
      emit({ id, ok: false, category: "provider", message: body.msg || body.message || "NetEase request failed", code: body.code });
    } else emit({ id, ok: true, body });
  } catch (error: any) {
    const status = error?.response?.status;
    emit({ id, ok: false, category: status === 301 || status === 401 ? "auth" : status === 502 ? "network" : "provider", sessionExpired: Boolean(session.MUSIC_U) && [301,401].includes(Number(error?.response?.body?.code)), message: status ? "NetEase request failed; retry or check your account" : "Network request failed; check your connection and retry", code: status });
  }
});
