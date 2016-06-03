using System;
using System.Linq;
using ServiceStack;
using ServiceStack.Text;
using ServiceStack.Api.Swagger;
using Funq;
using BasfSvr.ServiceInterface;
using BasfSvr.ServiceModel.Exceptions;
using System.Diagnostics;

namespace BasfSvr
{
    public class BasfSvrAppHost : AppSelfHostBase
    {
        private readonly NLog.Logger _logger = NLog.LogManager.GetCurrentClassLogger();

        public BasfSvrAppHost() : base("BasfSvr", typeof(BasfSvr.ServiceInterface.StatusService).Assembly)
		{
        }

        public override void Configure(Container container)
        {
            //Set JSON web services to return idiomatic JSON camelCase properties
            ServiceStack.Text.JsConfig.EmitCamelCaseNames = true;

            // overrides to default ServiceStack configuration
            SetConfig(new HostConfig
            {
                EnableFeatures = Feature.All,
                DefaultContentType = "application/json",
                DebugMode = true,       // show stack traces
                WriteErrorsToResponse = true
            });

            Plugins.Add(new RequestLogsFeature
            {
            });

            Plugins.Add(new SwaggerFeature
            {
                DisableAutoDtoInBodyParam = false,
            });

            // return dates like this: 2012-08-21T11:02:32.0449348-04:00
            ServiceStack.Text.JsConfig.DateHandler = ServiceStack.Text.DateHandler.ISO8601;

            // make sure default connection profile exists
            var cp = Basf.ConnectionProfiles.Get("DEF");
            if (cp == null)
                throw new TypeLoadException("Connection Profiles Not Configured");

            //Register IOC dependencies
            container.Register<DbContext>(ctx => new DbContext(cp)).ReusedWithin(ReuseScope.Request);

            // handle exceptions in services
            this.ServiceExceptionHandlers.Add((httpReq, requestDto, ex) =>
            {
                try
                {
                    // don't log certain exceptions
                    bool logIt = true;
                    if (ex is DoesNotExistsException) logIt = false;

                    //// don't log when Client already has latest version
                    //if (ex is HttpError)
                    //{
                    //    var httpErr = ex as HttpError;
                    //    if (httpErr.Status == 404 && requestDto is BasfSvr.ServiceModel.ClientUpdate)
                    //        logIt = false;
                    //}

                    if (logIt)
                    {
                        string msg = String.Format("Uri:{0}, Request:{0}", httpReq.AbsoluteUri, requestDto.ToJson());
                        _logger.ErrorException(msg, ex);

                        // this was logic to save exception data to database table so we could extract it later on
                        //ExceptionReport er = new ExceptionReport(ex, httpReq.Headers.ToDictionary());
                        //er.ContextInfo.Add("Verb", httpReq.Verb);
                        //er.ContextInfo.Add("AbsoluteUri", httpReq.AbsoluteUri);
                        //er.ContextInfo.Add("RequestType", requestDto.ToString());
                        //er.ContextInfo.Add("RequestData", requestDto.ToJson());
                        //using (var dbi = new DbInstance(cp))
                        //{
                        //    dbi.CtsErrorLog.Insert(new SmartGrocer.Data.Tables.CtsErrorLog
                        //    {
                        //        LogTime = DateTime.Now,
                        //        Json = er.GetJson(),
                        //        Program = er.AppName,
                        //        MachineName = er.MachineName,
                        //        ExceptionType = er.ExceptionType,
                        //        ExceptionMessage = er.Exception.Message,
                        //        AppUserName = er.UserName,
                        //    });
                        //}
                    }
                }
                catch (Exception)
                { }

                return DtoUtils.CreateErrorResponse(requestDto, ex);
            });

            // handle exceptions not in services
            this.UncaughtExceptionHandlers.Add((httpReq, httpResp, operationName, ex) =>
            {
                httpResp.Write("Error: {0}: {1}".Fmt(ex.GetType().Name, ex.Message));
                httpResp.EndRequest(skipHeaders: true);

                // logic to save error data to database for later extraction
                //try
                //{
                //    ExceptionReport er = new ExceptionReport(ex, httpReq.Headers.ToDictionary());
                //    er.ContextInfo.Add("Verb", httpReq.Verb);
                //    er.ContextInfo.Add("AbsoluteUri", httpReq.AbsoluteUri);
                //    using (var dbi = new DbInstance(cp))
                //    {
                //        dbi.CtsErrorLog.Insert(new SmartGrocer.Data.Tables.CtsErrorLog
                //        {
                //            LogTime = DateTime.Now,
                //            Json = er.GetJson(),
                //            Program = er.AppName,
                //            MachineName = er.MachineName,
                //            ExceptionType = er.ExceptionType,
                //            ExceptionMessage = er.Exception.Message,
                //            AppUserName = er.UserName,
                //        });
                //    }
                //}
                //catch (Exception)
                //{ }

            });

            this.GlobalRequestFilters.Add((req, res, dto) =>
            {
                Stopwatch sw = new Stopwatch();
                sw.Start();
                req.Items.Add("StopWatch", sw);

                var baseRequest = dto as BasfSvr.ServiceModel.BaseRequest;
                if (baseRequest == null)
                    return;
                var info = new BasfSvr.ServiceModel.BasfHttpRequestHeaders();
                object tempVal = req.GetHeader("X-Basf-UserId");
                info.UserName = tempVal == null ? "" : tempVal.ToString();
                tempVal = req.GetHeader("X-Basf-SiteId");
                info.SiteId = tempVal == null ? "" : tempVal.ToString();
                tempVal = req.GetHeader("X-Basf-ClientVersion");
                info.ClientVersion = tempVal == null ? "" : tempVal.ToString();
                baseRequest.BasfHeaders = info;
            });

            this.GlobalResponseFilters.Add((req, res, dto) =>
            {
                if (req.Items.ContainsKey("StopWatch"))
                {
                    var sw = req.Items["StopWatch"] as Stopwatch;
                    sw.Stop();

                    _logger.Debug("{0} {1} took {2:n0}ms (Client:{3}, Request:{4})", req.Verb, req.PathInfo, sw.ElapsedMilliseconds, req.RemoteIp, JsonSerializer.SerializeToString(req.Dto));

                    // don't long these types
                    if (dto is HttpResult) return;
                    //if (dto is BinaryDownloadResult) return;
                    //if (dto is ChunkedBinaryDownloadResult) return;

                    if (_logger.IsTraceEnabled)
                        _logger.Trace("Response: {0}", JsonSerializer.SerializeToString(dto));
                };
            });
        }
    }
}
