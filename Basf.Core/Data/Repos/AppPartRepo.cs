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
    public class AppPartRepo
    {
        private IDatabase _db;
        public AppPartRepo(IDatabase db)
        {
            _db = db;
        }

        public AppPart Get(string code, SqlTransaction tx = null)
        {
            // someday, map appropriate primary keys to the db table and get them into the classmapper so dapper will automatically figure them out
            var entity = _db.Connection.Query<AppPart>("SELECT * FROM AppPart WHERE appl_code=@p1", new { p1 = code }, tx).FirstOrDefault();
            return entity;
        }

        public List<AppPart> GetList(IPredicate pred = null, SqlTransaction tx = null)
        {
            return _db.Connection.GetList<AppPart>(pred, null, tx).OrderBy(x=>x.appl_code).ToList();
        }

        public void Insert(AppPart entity, SqlTransaction tx = null)
        {
            _db.Insert(entity, tx);
        }

        public bool Update(AppPart entity, SqlTransaction tx = null)
        {
            return _db.Update(entity, tx);
        }

        public void Upsert(AppPart entity, SqlTransaction tx = null)
        {
            if (!Update(entity, tx))
                Insert(entity, tx);
        }

        public void Delete(AppPart entity, SqlTransaction tx = null)
        {
            _db.Delete(entity, tx);
        }
    }
}
