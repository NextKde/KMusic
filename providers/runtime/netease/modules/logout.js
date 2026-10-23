// Generated from ../netease/modules/logout.ts by tools/build-provider-runtime.mjs; edit the TS source.
/**
 * 退出登录
 */

import { createOption } from "../core/option.js";
                                                      

const logout                = (query, request) => request("/api/logout", {}, createOption(query));

export default logout;
