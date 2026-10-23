// Generated from ../netease/modules/login_status.ts by tools/build-provider-runtime.mjs; edit the TS source.
/**
 * 登录状态（当前账号信息）
 */

import { createOption } from "../core/option.js";
                                                      

const loginStatus                = async (query, request) => {
  const result = await request("/api/w/nuser/account/get", {}, createOption(query, "weapi"));
  const body = result.body                                             ;
  if (body.code === 200) {
    return {
      status: 200,
      body: { data: { ...body } },
      cookie: result.cookie,
    };
  }
  return result;
};

export default loginStatus;
