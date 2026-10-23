// Generated from ../netease/modules/user_playlist.ts by tools/build-provider-runtime.mjs; edit the TS source.
/**
 * 用户歌单列表
 */

import { createOption } from "../core/option.js";
                                                      

const userPlaylist                = (query, request) => {
  const data = {
    uid: query.uid,
    limit: query.limit ?? 30,
    offset: query.offset ?? 0,
    includeVideo: true,
  };
  return request("/api/user/playlist", data, createOption(query, "weapi"));
};

export default userPlaylist;
