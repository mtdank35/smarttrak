using DapperExtensions.Mapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Basf.Data.Tables
{
    public class AppPart
    {
        public string appl_code { get; set; }

        public string appl_name { get; set; }

        public string lan_code { get; set; }

        public decimal? label_id { get; set; }
    }


    internal class AppPartMapper : ClassMapper<AppPart>
    {
        public AppPartMapper()
        {
            Table("apar0");
            Map(p => p.appl_code).Key(KeyType.Assigned);
            AutoMap();
        }
    }
}
