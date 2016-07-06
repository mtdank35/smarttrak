using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ServiceStack;
using System.Data.SqlClient;
using BasfSvr.ServiceModel;
using Humanizer;

namespace BasfSvr.ServiceInterface
{
    public class PourHdrsService : Service
    {
        public DbContext DbContext { get; set; }

        public object Get(PourHdrsRequest request)
        {
            using (var dbi = DbContext.NewCustDbInstance())
            {
                var things = dbi.PourHdr.GetList(null);
                var response = new PourHdrsResponse();
                response.PourHdrs = things.ToList();
                return response;
            }
        }
    }
}
