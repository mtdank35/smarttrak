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
    public class LocationsService : Service
    {
        public DbContext DbContext { get; set; }

        public object Get(LocationsRequest request)
        {
            using (var dbi = DbContext.NewCustDbInstance())
            {
                var things = dbi.Locations.GetList(null);
                var response = new LocationsResponse();
                response.Locations = things.ToList();
                return response;
            }
        }
    }
}
