using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BasfCli.Conf
{
    public class GlobalConf
    {
        public string IccmDbcs { get; set; }
        public string CustDataDbcs { get; set; }
        public string OutputDir { get; set; }

        public GlobalConf()
        {
            IccmDbcs = @"Data Source=.\SQL_ICCM;Initial Catalog=iccm_db;Integrated Security=False;User ID=sa;Password=123;Connect Timeout=5";
            CustDataDbcs = @"Data Source=.\SQL_ICCM;Initial Catalog=CustData;Integrated Security=False;User ID=sa;Password=123;Connect Timeout=5";
            OutputDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "BasfCli");
        }
    }
}
