// Generated from ../netease/modules/likelist.ts by tools/build-provider-runtime.mjs; edit the TS source.
/**
 * 喜欢歌曲 id 列表
 *
 * params:
 * - uid  用户 id
 *
 * 响应：`{ code, checkPoint, ids: number[] }`
 */

import { createOption } from "../core/option.js";
                                                      

const likelist                = (query, request) => {
  const data = { uid: query.uid };
  return request("/api/song/like/get", data, createOption(query));
};

export default likelist;
