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
import personalized from "./netease/modules/personalized.ts";
import topSong from "./netease/modules/top_song.ts";
import toplist from "./netease/modules/toplist.ts";
import recommendSongs from "./netease/modules/recommend_songs.ts";
import recommendResource from "./netease/modules/recommend_resource.ts";
import artists from "./netease/modules/artists.ts";
import artistAlbum from "./netease/modules/artist_album.ts";
import playlist from "./netease/modules/playlist_detail.ts";

import qrKey from "./netease/modules/login_qr_key.ts";
import qrCheck from "./netease/modules/login_qr_check.ts";
import loginStatus from "./netease/modules/login_status.ts";
import logout from "./netease/modules/logout.ts";
import { loadPersonal, clearPersonalSnapshots } from "./personal.ts";
import { cookieToJson } from "./netease/core/cookie.ts";

// Credentials stay in memory here and cross only the private parent/child pipe.
let session: Record<string, string> = {};
let authEpoch = 0;
const playlistSnapshots = new Map<string, any>();
function mergeCookies(lines: string[]) {
  for (const line of lines) Object.assign(session, cookieToJson(line.split(";")[0]));
}
function sessionString() { return Object.entries(session).map(([k,v]) => `${k}=${v}`).join("; "); }
const discoveryModules = { discoveryPlaylists: personalized, discoveryNewSongs: topSong,
  discoveryCharts: toplist, discoveryDailySongs: recommendSongs, discoveryDailyPlaylists: recommendResource };
const modules = { ...discoveryModules, artistAlbums: artistAlbum, search: cloudsearch, detail: songDetail, lyric, album, playlist, newAlbums: albumNew };
const input = createInterface({ input: process.stdin, crlfDelay: Infinity });
const emit = (data: unknown) => process.stdout.write(JSON.stringify(data) + "\n");
input.on("line", async (line) => {
  if (line.length > 32768) return;
  let id: number | string = "";
  const requestAuthEpoch = authEpoch;
  let discoveryRequest = false;
  let dailyDiscoveryRequest = false;
  let requestHadSession = false;
  let personalRequest = false;
  try {
    const req = JSON.parse(line);
    id = req.id;
    personalRequest = req.action === "personal";
    const params = { ...(req.params ?? {}), cookie: { ...session } };
    discoveryRequest = Object.hasOwn(discoveryModules, req.action);
    dailyDiscoveryRequest = req.action === "discoveryDailySongs" || req.action === "discoveryDailyPlaylists";
    if ((discoveryRequest && !dailyDiscoveryRequest) || req.action === "newAlbums") params.cookie = {};
    requestHadSession = Boolean(params.cookie.MUSIC_U);
    if (dailyDiscoveryRequest && !session.MUSIC_U) {
      emit({ id, ok: false, category: "auth", message: "Sign in to NetEase for daily recommendations" }); return;
    }
    if (req.action === "sessionRestore") {
      ++authEpoch; playlistSnapshots.clear(); clearPersonalSnapshots(); session = cookieToJson(String(req.params?.cookie || ""));
      emit({ id, ok: true }); return;
    }
    if (req.action === "logout") {
      ++authEpoch; playlistSnapshots.clear(); clearPersonalSnapshots(); session = {};
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
      emit({ id, ok: true, body: { authenticated: Boolean(account?.id && profile?.userId), nickname: profile?.nickname || "", avatarUrl: profile?.avatarUrl || "", userId: String(profile?.userId || "") } }); return;
    }
    if (personalRequest) {
      if (!session.MUSIC_U) { emit({ id, ok: false, category: "auth", message: "Sign in to NetEase to open Personal" }); return; }
      const body = await loadPersonal(params, () => requestAuthEpoch === authEpoch);
      if (requestAuthEpoch !== authEpoch) { emit({ id, ok: false, category: "cancelled", message: "Account changed" }); return; }
      emit({ id, ok: true, body }); return;
    }
    if (req.action === "artistTracks") {
      const response = await artists(params, createRequest);
      const body: any = response.body;
      const artist = body.artist;
      if (!artist) throw new Error("Artist unavailable");
      const songs = body.hotSongs || [];
      emit({ id, ok: true, body: { code: 200, songs, collection: {
        providerId: String(artist.id), kind: "artist", title: artist.name || "",
        artist: (artist.alias || []).join(" / "), artwork: artist.picUrl || artist.img1v1Url || "",
        description: artist.briefDesc || "", trackCount: songs.length, totalCount: songs.length,
        catalogueTrackCount: Number(artist.musicSize || 0), catalogueAlbumCount: Number(artist.albumSize || 0),
        scope: "popular", partial: false, source: "NetEase"
      } } }); return;
    }
    if (req.action === "playlistTracks") {
      const playlistId = String(params.id);
      const offset = Math.max(0, Number(req.params?.offset || 0));
      let list = offset > 0 ? playlistSnapshots.get(playlistId) : undefined;
      if (!list) {
        const response = await playlist(params, createRequest);
        list = (response.body as any).playlist;
        if (!list) throw new Error("Playlist unavailable");
        if (playlistSnapshots.size >= 5) playlistSnapshots.delete(playlistSnapshots.keys().next().value!);
        playlistSnapshots.set(playlistId, list);
      }
      const rawIds = (list.trackIds || []).map((x: any) => String(x.id));
      const ids = [...new Set<string>(rawIds.length ? rawIds : (list.tracks || []).map((x: any) => String(x.id)))];
      // A complete manifest may contain duplicate entries: count/load unique IDs.
      // If the server withholds IDs, preserve its declared count and disclose gaps.
      const declaredCount = Number(list.trackCount || 0);
      const total = rawIds.length >= declaredCount ? ids.length : Math.max(declaredCount, ids.length);
      const limit = 200;
      const wanted = ids.slice(offset, offset + limit);
      const known = new Map((list.tracks || []).map((song: any) => [String(song.id), song]));
      const missing = wanted.filter((songId: string) => !known.has(songId));
      for (let offset = 0; offset < missing.length; offset += 100) {
        const detail = await songDetail({ ids: missing.slice(offset, offset + 100).join(","), cookie: params.cookie }, createRequest);
        for (const song of ((detail.body as any).songs || [])) known.set(String(song.id), song);
      }
      const songs = wanted.map((songId: string) => known.get(songId)).filter(Boolean);
      emit({ id, ok: true, body: { code: 200, songs, collection: {
        providerId: String(list.id), kind: "playlist", title: list.name || "", artist: list.creator?.nickname || "",
        artwork: list.coverImgUrl || "", description: list.description || "", trackCount: songs.length,
        totalCount: total, partial: true, requestedCount: Math.min(offset + wanted.length, ids.length),
        nextOffset: Math.min(offset + wanted.length, ids.length), hasMore: offset + wanted.length < ids.length,
        listedCount: ids.length, loadLimit: limit, source: "NetEase"
      } } }); return;
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
    if ((dailyDiscoveryRequest || personalRequest) && requestAuthEpoch !== authEpoch) {
      emit({ id, ok: false, category: "cancelled", message: "Account changed" }); return;
    }
    if (body.code === 301 || body.code === 401 || body.code === -460) {
      emit({ id, ok: false, category: "auth", sessionExpired: requestHadSession && requestAuthEpoch === authEpoch && [301,401].includes(Number(body.code)), message: "NetEase login is required or expired", code: body.code });
    } else if (body.code && body.code !== 200) {
      emit({ id, ok: false, category: "provider", message: body.msg || body.message || "NetEase request failed", code: body.code });
    } else emit({ id, ok: true, body });
  } catch (error: any) {
    if ((dailyDiscoveryRequest || personalRequest) && requestAuthEpoch !== authEpoch) {
      emit({ id, ok: false, category: "cancelled", message: "Account changed" }); return;
    }
    const status = error?.response?.status;
    emit({ id, ok: false, category: status === 301 || status === 401 ? "auth" : status === 502 ? "network" : "provider", sessionExpired: requestHadSession && requestAuthEpoch === authEpoch && [301,401].includes(Number(error?.response?.body?.code)), message: status ? "NetEase request failed; retry or check your account" : "Network request failed; check your connection and retry", code: status });
  }
});
