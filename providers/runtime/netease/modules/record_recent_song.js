// Generated from ../netease/modules/record_recent_song.ts by tools/build-provider-runtime.mjs; edit the TS source.
// Adapted from pinned SPlayer Next record_recent_song.ts (AGPL-3.0).
// KMusic has no Electron web-client: explicitly use native weapi for the same
// chronological-record endpoint. Do not substitute user_record listening ranks.
import { createOption } from "../core/option.js";
                                                      
const recordRecentSong                = (query, request) => request(
  "/api/play-record/song/list", { limit: query.limit ?? 100 }, createOption(query, "weapi"));
export default recordRecentSong;
