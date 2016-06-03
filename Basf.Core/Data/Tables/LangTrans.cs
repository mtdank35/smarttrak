using DapperExtensions.Mapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Basf.Data.Tables
{
    public class LangTrans
    {
        public int lang_code { get; set; }
        public int label_id { get; set; }
        public string label_text { get; set; }
        public int? max_len { get; set; }

        // control if we really need the 'x' prefix or not...
        private bool _lblPrefix = true;

        public string lbl_id
        {
            get
            {
                if (_lblPrefix)
                    return this.label_id == 0 ? "" : String.Format("b{0:#0}", this.label_id);
                else
                    return this.label_id == 0 ? "" : String.Format("{0:#0}", this.label_id);
            }
        }
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
