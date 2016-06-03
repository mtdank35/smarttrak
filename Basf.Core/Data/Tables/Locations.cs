using DapperExtensions.Mapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Basf.Data.Tables
{
    public class Locations
    {
        public int seqid { get; set; }
        public string loc_code { get; set; }
        public string loc_desc { get; set; }
    }

    internal class LocationsMapper : ClassMapper<Locations>
    {
        public LocationsMapper()
        {
            Map(p => p.seqid).Key(KeyType.Assigned);
            AutoMap();
        }
    }
}
