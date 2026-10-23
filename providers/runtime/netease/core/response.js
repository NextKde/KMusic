// Generated from ../netease/core/response.ts by tools/build-provider-runtime.mjs; edit the TS source.
/** 响应统一结构 */
                                  
                 
                                
                   
 

/** 非 200 响应抛出的错误 */
export class NeteaseRequestError extends Error {
           response                 ;

  /**
   * 保留服务端业务结果，供调用方识别失败原因
   * @param response - 未成功的请求响应
   */
  constructor(response                 ) {
    const body = response.body                                                              ;
    const code = body?.code ?? response.status;
    const msg = body?.msg ?? body?.message ?? "";
    super(msg ? `netease ${code}: ${msg}` : `netease ${code}`);
    this.name = "NeteaseRequestError";
    this.response = response;
  }
}
