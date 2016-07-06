using DapperExtensions.Mapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Basf.Data.Tables
{
    public class ColorTypes
    {
        public string typedesc { get; set; }

        public string colortype { get; set; }
    }


    internal class ColorTypesMapper : ClassMapper<ColorTypes>
    {
        public ColorTypesMapper()
        {
            Table("colortypes");
            Map(p => p.colortype).Key(KeyType.Assigned);
            AutoMap();
        }
    }
}
