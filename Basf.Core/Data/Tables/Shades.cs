using DapperExtensions.Mapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Basf.Data.Tables
{
    public class Shades
    {
        public string tval_shade { get; set; }

        public string shadedesc { get; set; }

        public decimal? label_id { get; set; }

        public string rgb { get; set; }

        public string file_name { get; set; }
    }


    internal class ShadesMapper : ClassMapper<Shades>
    {
        public ShadesMapper()
        {
            Map(p => p.tval_shade).Key(KeyType.Assigned);
            AutoMap();
        }
    }
}
