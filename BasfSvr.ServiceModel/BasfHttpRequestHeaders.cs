using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BasfSvr.ServiceModel
{
    public class BasfHttpRequestHeaders
    {
        // FUTURE: any other things to pass along here
        public string UserName { get; set; }
        public string SiteId { get; set; }
        public string ClientVersion { get; set; }
    }
}
