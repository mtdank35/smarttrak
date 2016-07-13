using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using Dapper;
using DapperExtensions;
using Basf.Data.Tables;
using DapperExtensions.Sql;
using DapperExtensions.Mapper;
using System.Reflection;


namespace Basf.Data.Repos
{
    public class JobHeaderRepo
    {
        private IDatabase _db;
        public JobHeaderRepo(IDatabase db)
        {
            _db = db;
        }

        public JobHeader Get(string code, SqlTransaction tx = null)
        {
            // someday, map appropriate primary keys to the db table and get them into the classmapper so dapper will automatically figure them out
            var entity = _db.Connection.Query<JobHeader>("SELECT * FROM job_hdr WHERE job_id=@p1", new { p1 = code }, tx).FirstOrDefault();
            return entity;
        }

        public List<JobHeader> GetList(IPredicate pred = null, SqlTransaction tx = null)
        {
            return _db.Connection.GetList<JobHeader>(pred, null, tx).OrderBy(x => x.job_id).ToList();
        }

        public void Insert(JobHeader entity, SqlTransaction tx = null)
        {
            _db.Insert(entity, tx);
        }

        public bool Update(JobHeader entity, SqlTransaction tx = null)
        {
            return _db.Update(entity, tx);
        }

        public void Upsert(JobHeader entity, SqlTransaction tx = null)
        {
            if (!Update(entity, tx))
                Insert(entity, tx);
        }

        public void Delete(JobHeader entity, SqlTransaction tx = null)
        {
            _db.Delete(entity, tx);
        }

    }
}
