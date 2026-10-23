// Generated from ../netease/modules/top_song.ts by tools/build-provider-runtime.mjs; edit the TS source.
// KMusic endpoint adapter, not a module copied from pinned SPlayer Next.
// Uses the attributed SPlayer request stack; endpoint shape cross-checked against
// NeteaseCloudMusicApiEnhanced/api-enhanced module/top_song.js.
import { createOption } from "../core/option.js";
                                                      
const topSong                = (query, request) => request(
  "/api/v1/discovery/new/songs", { areaId: query.type ?? 0, total: true }, createOption(query, "weapi"));
export default topSong;
