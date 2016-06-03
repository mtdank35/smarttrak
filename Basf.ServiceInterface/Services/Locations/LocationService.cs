using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ServiceStack;
using System.Data.SqlClient;
using BasfSvr.ServiceModel;
using Humanizer;
using BasfSvr.ServiceModel.Exceptions;

namespace BasfSvr.ServiceInterface
{
    public class LocationService : Service
    {
        public DbContext DbContext { get; set; }

        public object Get(LocationRequest request)
        {
            using (var dbi = DbContext.NewCustDbInstance())
            {
                var thing = dbi.Locations.Get(request.LocId);
                if (thing == null)
                    throw new DoesNotExistException(String.Format("Location {0} does not exist", request.LocId));
                var response = new LocationResponse();
                response.Location = thing;
                return response;
            }
        }

        public object Delete(LocationRequest request)
        {
            // delete object
            using (var dbi = DbContext.NewCustDbInstance())
            {
                dbi.Locations.Delete(request.Loc);
                return true;
            }
        }

        public object Post(LocationRequest request)
        {
            // insert a new object
            using (var dbi = DbContext.NewCustDbInstance())
            {
                dbi.Locations.Insert(request.Loc);
                var response = new LocationResponse();
                response.Location = dbi.Locations.Get(request.Loc.seqid);
                return response;
            }
        }

        public object Put(LocationRequest request)
        {
            // update existing object
            using (var dbi = DbContext.NewCustDbInstance())
            {
                var thing = dbi.Locations.Get(request.LocId);
                if (thing == null)
                    throw new DoesNotExistException("Location {0} does not exist".Fmt(request.Loc.seqid));

                dbi.Locations.Update(request.Loc);
                var response = new LocationResponse();
                response.Location = request.Loc;
                return response;
            }
        }

    }
}
