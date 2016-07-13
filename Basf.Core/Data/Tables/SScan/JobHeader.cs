using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using DapperExtensions.Mapper;
using Newtonsoft.Json;
using System.Runtime.Serialization;

namespace Basf.Data.Tables
{
    //public class JobHeader
    //{
    //    private decimal _job_id;
    //    public decimal job_id
    //    {
    //        get
    //        {
    //            return _job_id;
    //        }
    //        set
    //        {
    //            if (DataUtils.IsDifferent(_job_id, value))
    //            {
    //                _job_id = value;
    //                this.IsDirty = true;
    //            }
    //        }
    //    }

    //    private string _name;
    //    public string name
    //    {
    //        get
    //        {
    //            return _name;
    //        }
    //        set
    //        {
    //            if (DataUtils.IsDifferent(_name, value))
    //            {
    //                _name = value;
    //                this.IsDirty = true;
    //            }
    //        }
    //    }

    //    private DateTime _date_act;
    //    public DateTime date_act
    //    {
    //        get
    //        {
    //            return _date_act;
    //        }
    //        set
    //        {
    //            if (DataUtils.IsDifferent(_date_act, value))
    //            {
    //                _date_act = value;
    //                this.IsDirty = true;
    //            }
    //        }
    //    }

    //    private string _time_act;
    //    public string time_act
    //    {
    //        get
    //        {
    //            return _time_act;
    //        }
    //        set
    //        {
    //            if (DataUtils.IsDifferent(_time_act, value))
    //            {
    //                _time_act = value;
    //                this.IsDirty = true;
    //            }
    //        }
    //    }

    //    private string _status;
    //    public string status
    //    {
    //        get
    //        {
    //            return _status;
    //        }
    //        set
    //        {
    //            if (DataUtils.IsDifferent(_status, value))
    //            {
    //                _status = value;
    //                this.IsDirty = true;
    //            }
    //        }
    //    }

    //    private decimal _col_code;
    //    public decimal col_code
    //    {
    //        get
    //        {
    //            return _col_code;
    //        }
    //        set
    //        {
    //            if (DataUtils.IsDifferent(_col_code, value))
    //            {
    //                _col_code = value;
    //                this.IsDirty = true;
    //            }
    //        }
    //    }

    //    private string _col_node;
    //    public string col_node
    //    {
    //        get
    //        {
    //            return _col_node;
    //        }
    //        set
    //        {
    //            if (DataUtils.IsDifferent(_col_node, value))
    //            {
    //                _col_node = value;
    //                this.IsDirty = true;
    //            }
    //        }
    //    }

    //    private string _pline1;
    //    public string pline1
    //    {
    //        get
    //        {
    //            return _pline1;
    //        }
    //        set
    //        {
    //            if (DataUtils.IsDifferent(_pline1, value))
    //            {
    //                _pline1 = value;
    //                this.IsDirty = true;
    //            }
    //        }
    //    }

    //    private string _file1;
    //    public string file1
    //    {
    //        get
    //        {
    //            return _file1;
    //        }
    //        set
    //        {
    //            if (DataUtils.IsDifferent(_file1, value))
    //            {
    //                _file1 = value;
    //                this.IsDirty = true;
    //            }
    //        }
    //    }

    //    private string _crc_flag;
    //    public string crc_flag
    //    {
    //        get
    //        {
    //            return _crc_flag;
    //        }
    //        set
    //        {
    //            if (DataUtils.IsDifferent(_crc_flag, value))
    //            {
    //                _crc_flag = value;
    //                this.IsDirty = true;
    //            }
    //        }
    //    }

    //    private string _id2;
    //    public string id2
    //    {
    //        get
    //        {
    //            return _id2;
    //        }
    //        set
    //        {
    //            if (DataUtils.IsDifferent(_id2, value))
    //            {
    //                _id2 = value;
    //                this.IsDirty = true;
    //            }
    //        }
    //    }

    //    private string _var2;
    //    public string var2
    //    {
    //        get
    //        {
    //            return _var2;
    //        }
    //        set
    //        {
    //            if (DataUtils.IsDifferent(_var2, value))
    //            {
    //                _var2 = value;
    //                this.IsDirty = true;
    //            }
    //        }
    //    }

    //    private string _pline2;
    //    public string pline2
    //    {
    //        get
    //        {
    //            return _pline2;
    //        }
    //        set
    //        {
    //            if (DataUtils.IsDifferent(_pline2, value))
    //            {
    //                _pline2 = value;
    //                this.IsDirty = true;
    //            }
    //        }
    //    }

    //    private string _file2;
    //    public string file2
    //    {
    //        get
    //        {
    //            return _file2;
    //        }
    //        set
    //        {
    //            if (DataUtils.IsDifferent(_file2, value))
    //            {
    //                _file2 = value;
    //                this.IsDirty = true;
    //            }
    //        }
    //    }

    //    private string _adjflag;
    //    public string adjflag
    //    {
    //        get
    //        {
    //            return _adjflag;
    //        }
    //        set
    //        {
    //            if (DataUtils.IsDifferent(_adjflag, value))
    //            {
    //                _adjflag = value;
    //                this.IsDirty = true;
    //            }
    //        }
    //    }

    //    private string _adjpntln;
    //    public string adjpntln
    //    {
    //        get
    //        {
    //            return _adjpntln;
    //        }
    //        set
    //        {
    //            if (DataUtils.IsDifferent(_adjpntln, value))
    //            {
    //                _adjpntln = value;
    //                this.IsDirty = true;
    //            }
    //        }
    //    }

    //    private string _st_msg;
    //    public string st_msg
    //    {
    //        get
    //        {
    //            return _st_msg;
    //        }
    //        set
    //        {
    //            if (DataUtils.IsDifferent(_st_msg, value))
    //            {
    //                _st_msg = value;
    //                this.IsDirty = true;
    //            }
    //        }
    //    }

    //    private decimal _sol_code;
    //    public decimal sol_code
    //    {
    //        get
    //        {
    //            return _sol_code;
    //        }
    //        set
    //        {
    //            if (DataUtils.IsDifferent(_sol_code, value))
    //            {
    //                _sol_code = value;
    //                this.IsDirty = true;
    //            }
    //        }
    //    }

    //    private string _sol_node;
    //    public string sol_node
    //    {
    //        get
    //        {
    //            return _sol_node;
    //        }
    //        set
    //        {
    //            if (DataUtils.IsDifferent(_sol_node, value))
    //            {
    //                _sol_node = value;
    //                this.IsDirty = true;
    //            }
    //        }
    //    }

    //    private decimal _cop_code;
    //    public decimal cop_code
    //    {
    //        get
    //        {
    //            return _cop_code;
    //        }
    //        set
    //        {
    //            if (DataUtils.IsDifferent(_cop_code, value))
    //            {
    //                _cop_code = value;
    //                this.IsDirty = true;
    //            }
    //        }
    //    }

    //    private string _cop_node;
    //    public string cop_node
    //    {
    //        get
    //        {
    //            return _cop_node;
    //        }
    //        set
    //        {
    //            if (DataUtils.IsDifferent(_cop_node, value))
    //            {
    //                _cop_node = value;
    //                this.IsDirty = true;
    //            }
    //        }
    //    }

    //    private decimal _cop_code2;
    //    public decimal cop_code2
    //    {
    //        get
    //        {
    //            return _cop_code2;
    //        }
    //        set
    //        {
    //            if (DataUtils.IsDifferent(_cop_code2, value))
    //            {
    //                _cop_code2 = value;
    //                this.IsDirty = true;
    //            }
    //        }
    //    }

    //    private string _cop_node2;
    //    public string cop_node2
    //    {
    //        get
    //        {
    //            return _cop_node2;
    //        }
    //        set
    //        {
    //            if (DataUtils.IsDifferent(_cop_node2, value))
    //            {
    //                _cop_node2 = value;
    //                this.IsDirty = true;
    //            }
    //        }
    //    }

    //    private decimal _o_col_code;
    //    public decimal o_col_code
    //    {
    //        get
    //        {
    //            return _o_col_code;
    //        }
    //        set
    //        {
    //            if (DataUtils.IsDifferent(_o_col_code, value))
    //            {
    //                _o_col_code = value;
    //                this.IsDirty = true;
    //            }
    //        }
    //    }

    //    private string _o_col_node;
    //    public string o_col_node
    //    {
    //        get
    //        {
    //            return _o_col_node;
    //        }
    //        set
    //        {
    //            if (DataUtils.IsDifferent(_o_col_node, value))
    //            {
    //                _o_col_node = value;
    //                this.IsDirty = true;
    //            }
    //        }
    //    }

    //    private decimal? _adjallowed;
    //    public decimal? adjallowed
    //    {
    //        get
    //        {
    //            return _adjallowed;
    //        }
    //        set
    //        {
    //            if (DataUtils.IsDifferent(_adjallowed, value))
    //            {
    //                _adjallowed = value;
    //                this.IsDirty = true;
    //            }
    //        }
    //    }

    //    private string _job_no;
    //    public string job_no
    //    {
    //        get
    //        {
    //            return _job_no;
    //        }
    //        set
    //        {
    //            if (DataUtils.IsDifferent(_job_no, value))
    //            {
    //                _job_no = value;
    //                this.IsDirty = true;
    //            }
    //        }
    //    }

    //    [IgnoreDataMember]
    //    public bool IsDirty { get; set; }

    //}


    public class JobHeader
    {
        public decimal job_id { get; set; }

        public string name { get; set; }

        public DateTime date_act { get; set; }

        public string time_act { get; set; }

        public string status { get; set; }

        public decimal col_code { get; set; }

        public string col_node { get; set; }

        public string pline1 { get; set; }

        public string file1 { get; set; }

        public string crc_flag { get; set; }

        public string id2 { get; set; }

        public string var2 { get; set; }

        public string pline2 { get; set; }

        public string file2 { get; set; }

        public string adjflag { get; set; }

        public string adjpntln { get; set; }

        public string st_msg { get; set; }

        public decimal sol_code { get; set; }

        public string sol_node { get; set; }

        public decimal cop_code { get; set; }

        public string cop_node { get; set; }

        public decimal cop_code2 { get; set; }

        public string cop_node2 { get; set; }

        public decimal o_col_code { get; set; }

        public string o_col_node { get; set; }

        public decimal? adjallowed { get; set; }

        public string job_no { get; set; }

    }

    internal class JobHeaderMapper : ClassMapper<JobHeader>
    {
        public JobHeaderMapper()
        {
            Table("job_Hdr");
            Map(p => p.job_id).Key(KeyType.Assigned);
            AutoMap();
        }
    }
}




