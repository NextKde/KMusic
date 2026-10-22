// Adapted from pinned SPlayer Next record_recent_song.ts (AGPL-3.0).
// KMusic has no Electron web-client: explicitly use native weapi for the same
// chronological-record endpoint. Do not substitute user_record listening ranks.
import { createOption } from "../core/option.ts";
import type { NeteaseModule } from "../core/types.ts";
const recordRecentSong: NeteaseModule = (query, request) => request(
  "/api/play-record/song/list", { limit: query.limit ?? 100 }, createOption(query, "weapi"));
export default recordRecentSong;
