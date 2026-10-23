// Generated from ../personal.ts by tools/build-provider-runtime.mjs; edit the TS source.
// KMusic personal-library lifecycle and paging; upstream modules retain their
// SPlayer Next AGPL notices in netease/NOTICE.md. Never persists account content.
import { createRequest } from "./netease/core/request.js";
                                                             
import userPlaylist from "./netease/modules/user_playlist.js";
import likelist from "./netease/modules/likelist.js";
import albumSublist from "./netease/modules/album_sublist.js";
import artistSublist from "./netease/modules/artist_sublist.js";
import recentSong from "./netease/modules/record_recent_song.js";
import songDetail from "./netease/modules/song_detail.js";

const likedSnapshots = new Map                  ();
export function clearPersonalSnapshots() { likedSnapshots.clear(); }
export async function loadPersonal(params     , isCurrent               ) {
  const section = String(params.section || "");
  const uid = String(params.uid || "");
  const offset = Math.max(0, Math.floor(Number(params.offset) || 0));
  const cookie = params.cookie;
  const read = async (module               , query     )               => {
    const response = await module({ ...query, cookie }, createRequest);
    if (!isCurrent()) throw new Error("Account changed");
    const body      = response.body;
    if (body.code && Number(body.code) !== 200) {
      const error      = new Error("NetEase personal request failed"); error.response = response; throw error;
    }
    return body;
  };
  const artists = (list       ) => (list || []).map(a => a.name || "").filter(Boolean).join(" / ");
  const row = (item     , kind        ) => ({ providerId: String(item.id || ""), kind,
    title: item.name || "", artist: kind === "playlist" ? item.creator?.nickname || "" : kind === "artist" ? (item.alias || []).join(" / ") : artists(item.artists),
    artwork: item.coverImgUrl || item.picUrl || item.img1v1Url || "", description: item.description || "",
    totalCount: Number(item.trackCount || item.size || item.musicSize || 0), source: "NetEase" });
  const validRows = (rows       ) => rows.filter(x => x.providerId && x.providerId !== "0" && x.title);
  const page = (raw       , body     , scopeLabel        ) => {
    const nextOffset = offset + raw.length;
    const total = Number.isFinite(Number(body.count)) && body.count != null ? Number(body.count) : -1;
    const more = typeof body.hasMore === "boolean" ? body.hasMore : typeof body.more === "boolean" ? body.more : total >= 0 ? nextOffset < total : raw.length >= 50;
    if (more && !raw.length) throw new Error("NetEase returned an empty page before the end");
    return { nextOffset, more, total, scopeLabel };
  };
  if (section === "createdPlaylists" || section === "savedPlaylists") {
    if (!uid) throw new Error("Account identity unavailable");
    const body = await read(userPlaylist, { uid, offset, limit: 50 });
    const raw = body.playlist || [];
    const items = raw.filter((p     ) => {
      const created = String(p.creator?.userId || "") === uid;
      return section === "createdPlaylists" ? created : !created;
    }).map((p     ) => row(p, "playlist"));
    const pagination = page(raw, body, section === "createdPlaylists" ? "NetEase created playlists · paged account list" : "NetEase saved playlists · paged account list");
    // The API cursor/count refers to a mixed list, not either filtered category.
    pagination.total = -1;
    return { code: 200, items: validRows(items), page: pagination };
  }
  if (section === "savedAlbums" || section === "savedArtists") {
    const body = await read(section === "savedAlbums" ? albumSublist : artistSublist, { offset, limit: 50 });
    const raw = body.data || [];
    return { code: 200, items: validRows(raw.map((p     ) => row(p, section === "savedAlbums" ? "album" : "artist"))),
      page: page(raw, body, section === "savedAlbums" ? "NetEase saved albums" : "NetEase followed artists") };
  }
  if (section === "likedSongs") {
    if (!uid) throw new Error("Account identity unavailable");
    let ids = offset > 0 ? likedSnapshots.get(uid) : undefined;
    if (!ids) {
      if (offset > 0) throw new Error("Liked-song snapshot expired; refresh Personal");
      const body = await read(likelist, { uid });
      ids = [...new Set        ((body.ids || []).map((id     ) => String(id)).filter((id        ) => id && id !== "0"))];
      likedSnapshots.clear(); likedSnapshots.set(uid, ids);
    }
    const wanted = ids.slice(offset, offset + 100);
    const body = wanted.length ? await read(songDetail, { ids: wanted.join(",") }) : { songs: [] };
    const known = new Map             ((body.songs || []).map((song     ) => [String(song.id), song]));
    const songs = wanted.map(id => known.get(id)).filter((song     ) => song?.id && song?.name);
    return { code: 200, songs, page: { nextOffset: offset + wanted.length, more: offset + wanted.length < ids.length,
      total: ids.length, omittedCount: wanted.length - songs.length, scopeLabel: "NetEase liked songs · account ID order" } };
  }
  if (section === "recentSongs") {
    // This upstream endpoint accepts only limit, not an offset. Explicitly bounded
    // service history, not the local recent table or user_record play-count rank.
    const body = await read(recentSong, { limit: 100 });
    const list = (body.data?.list || []).slice(0, 100);
    const songOf = (entry     ) => entry.data?.song || entry.data || entry.song || {};
    const missing = [...new Set        (list.filter((entry     ) => !songOf(entry).name)
      .map((entry     ) => String(entry.resourceId || songOf(entry).id || "")).filter((id        ) => id && id !== "0"))];
    const details = missing.length ? await read(songDetail, { ids: missing.join(",") }) : { songs: [] };
    const known = new Map             ((details.songs || []).map((song     ) => [String(song.id), song]));
    const records = list.map((entry     , index        ) => {
      const id = String(entry.resourceId || songOf(entry).id || "");
      return { song: songOf(entry).name ? songOf(entry) : known.get(id), playedAt: Number(entry.playTime || 0), entryId: `${id}:${entry.playTime || 0}:${index}` };
    }).filter((entry     ) => entry.song?.id && entry.song?.name);
    return { code: 200, records, page: { nextOffset: list.length, more: false, total: -1,
      omittedCount: list.length - records.length, limit: 100, scopeLabel: "NetEase recent plays · latest up to 100 · service order" } };
  }
  throw new Error("Unsupported personal section");
}
