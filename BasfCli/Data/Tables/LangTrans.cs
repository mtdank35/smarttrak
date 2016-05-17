using DapperExtensions.Mapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BasfCli.Data.Tables
{
    public class LangTrans
    {
        public int lang_code { get; set; }
        public int label_id { get; set; }
        public string label_text { get; set; }
        public int? max_len { get; set; }
    }

    internal class LangTransMapper : ClassMapper<LangTrans>
    {
        public LangTransMapper()
        {
            Map(p => p.lang_code).Key(KeyType.Assigned);
            Map(p => p.label_id).Key(KeyType.Assigned);
            AutoMap();
        }
    }
}
