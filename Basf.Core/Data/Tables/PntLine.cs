using DapperExtensions.Mapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Basf.Data.Tables
{
    public class PntLine
    {
        public string paintline { get; set; }

        public string brandcode { get; set; }

        public string bcodeadd { get; set; }

        public string linename { get; set; }

        public bool? custavai { get; set; }

        public decimal? sortorder { get; set; }

        public decimal? label_id { get; set; }

        public string upd_flag { get; set; }

        public decimal? infoid { get; set; }

        public string areacode { get; set; }

        public string arcticcode { get; set; }

    }


    internal class PntLineMapper : ClassMapper<PntLine>
    {
        public PntLineMapper()
        {
            Table("pntline0");
            Map(p => p.paintline).Key(KeyType.Assigned);
            Map(p => p.brandcode).Key(KeyType.Assigned);
            AutoMap();
        }
    }
}
