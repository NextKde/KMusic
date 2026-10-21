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

const modules = { search: cloudsearch, detail: songDetail, lyric, album, playlist, newAlbums: albumNew };
const input = createInterface({ input: process.stdin, crlfDelay: Infinity });
const emit = (data: unknown) => process.stdout.write(JSON.stringify(data) + "\n");
input.on("line", async (line) => {
  if (line.length > 32768) return;
  let id: number | string = "";
  try {
    const req = JSON.parse(line);
    id = req.id;
    const params = req.params ?? {};
    if (req.action === "resolve") {
      const details = await songDetail({ ids: String(params.songId) }, createRequest);
      const response = await songUrl({ id: String(params.songId), level: params.level || "standard" }, createRequest);
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
      emit({ id, ok: false, category: "auth", message: "NetEase login is required or expired", code: body.code });
    } else if (body.code && body.code !== 200) {
      emit({ id, ok: false, category: "provider", message: body.msg || body.message || "NetEase request failed", code: body.code });
    } else emit({ id, ok: true, body });
  } catch (error: any) {
    const status = error?.response?.status;
    emit({ id, ok: false, category: status === 301 || status === 401 ? "auth" : status === 502 ? "network" : "provider", message: String(error?.message || error).slice(0, 500), code: status });
  }
});
