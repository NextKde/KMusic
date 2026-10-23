// Generated from ../netease/modules/artist_sublist.ts by tools/build-provider-runtime.mjs; edit the TS source.
/**
 * 用户收藏的歌手列表
 *
 * params:
 * - limit / offset 分页
 *
 * 响应：`{ code, count, hasMore, data: [{ id, name, picUrl, albumSize, ... }] }`
 */

import { createOption } from "../core/option.js";
                                                      

const artistSublist                = (query, request) => {
  const data = {
    limit: query.limit ?? 50,
    offset: query.offset ?? 0,
    total: true,
  };
  return request("/api/artist/sublist", data, createOption(query, "weapi"));
};

export default artistSublist;
