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
    public class StatusService : Service
    {
        public DbContext DbContext { get; set; }

        public object Get(Status request)
        {
            SqlConnectionStringBuilder custCb = new SqlConnectionStringBuilder(DbContext.CustDbcs);
            SqlConnectionStringBuilder iccmCb = new SqlConnectionStringBuilder(DbContext.IccmDbcs);
            bool custDbAvail = false;
            string custDbError = null;
            try
            {
                using (var cn = new SqlConnection(custCb.ConnectionString))
                {
                    cn.Open();
                    custDbAvail = true;
                }
            }
            catch (SqlException sqlEx)
            {
                custDbError = String.Format("{0} ({1:g0})", sqlEx.Message, sqlEx.Number);
            }
            catch (Exception ex)
            {
                custDbError = String.Format("{0}", ex.Message);
            }

            return new StatusResponse
            {
                LocalTime = DateTime.Now,
                CustDbServer = custCb.DataSource,
                CustDbName = custCb.InitialCatalog,
                CustDbAvail = custDbAvail,
                CustDbError = custDbError,
                UtcTime = DateTime.UtcNow,
                Version = "1.0.9999.9999",
                MachineName = Environment.MachineName,
                OSVersion = Environment.OSVersion.ToString(),
                Uptime = TimeSpan.FromMilliseconds(Environment.TickCount).Humanize(5),
                IccmDbName = iccmCb.InitialCatalog,
                IccmDbServer = iccmCb.DataSource,
            };
        }
    }
}
