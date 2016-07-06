using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using ServiceStack;
using System.Data.SqlClient;
using DapperExtensions;
using Humanizer;
using Basf.Data.Tables;
using BasfSvr.ServiceModel;
using BasfSvr.ServiceModel.Exceptions;

namespace BasfSvr.ServiceInterface
{
    public class LookupService : Service
    {
        public DbContext DbContext { get; set; }

        public object Get(LookupRequest request)
        {
            using (var dbi = DbContext.NewDataDbInstance())
            {
                var response = new LookupResponse();
                switch (request.LookupType.ToUpperInvariant())
                {
                    case "PNTLINE":
                        // limit to custavai=1
                        var pred = Predicates.Field<PntLine>(x => x.custavai, Operator.Eq, true);
                        var lines = dbi.PntLine.GetList(pred);
                        if (lines.Count > 0)
                        {
                            response.Values = new List<Lookup>();
                            foreach (var line in lines)
                                response.Values.Add(new Lookup() { DbVal = line.paintline, DisplayVal = line.linename });
                        }
                        break;
                    case "COLORTYPES":
                        var types = dbi.ColorType.GetList();
                        if (types.Count > 0)
                        {
                            response.Values = new List<Lookup>();
                            foreach (var typ in types)
                                response.Values.Add(new Lookup() { DbVal = typ.colortype, DisplayVal = typ.typedesc });
                        }
                        break;
                    case "SHADES":
                        var shades = dbi.Shades.GetList();
                        if (shades.Count > 0)
                        {
                            response.Values = new List<Lookup>();
                            foreach (var shade in shades)
                                response.Values.Add(new Lookup() { DbVal = shade.tval_shade, DisplayVal = shade.shadedesc });
                        }
                        break;
                    default:
                        throw new HttpError(System.Net.HttpStatusCode.NotAcceptable, "INVALID_LOOKUP_TYPE",
                            String.Format("LookupType '{0}' not valid.", request.LookupType));
                }
                return response;
            }
        }
    }
}