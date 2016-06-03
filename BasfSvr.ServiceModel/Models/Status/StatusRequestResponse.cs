using System;
using ServiceStack;

namespace BasfSvr.ServiceModel
{
    [Route("/status")]
    public class Status
    {
    }

    public class StatusResponse : BaseResponse
    {
        public string Version { get; set; }
        public DateTime UtcTime { get; set; }
        public DateTime LocalTime { get; set; }
        public string MachineName { get; set; }
        public string OSVersion { get; set; }
        public string Uptime { get; set; }

        public string CustDbName { get; set; }
        public bool CustDbAvail { get; set; }
        public string CustDbError { get; set; }
        public string CustDbServer { get; set; }

        public string IccmDbName { get; set; }
        public string IccmDbServer { get; set; }
    }
}
