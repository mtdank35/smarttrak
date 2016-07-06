using DapperExtensions.Mapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Basf.Data.Tables
{
    public class ProdType
    {
        public string code { get; set; }

        public string descrip { get; set; }

        public decimal? label_id { get; set; }
    }


    internal class ProdTypeMapper : ClassMapper<ProdType>
    {
        public ProdTypeMapper()
        {
            Map(p => p.code).Key(KeyType.Assigned);
            AutoMap();
        }
    }
}
