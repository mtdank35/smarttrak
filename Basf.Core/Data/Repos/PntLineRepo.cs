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
    public class PntLineRepo
    {
        private IDatabase _db;
        public PntLineRepo(IDatabase db)
        {
            _db = db;
        }

        public PntLine Get(string line, string brandCd, SqlTransaction tx = null)
        {
            // someday, map appropriate primary keys to the db table and get them into the classmapper so dapper will automatically figure them out
            var entity = _db.Connection.Query<PntLine>("SELECT * FROM pntline0 where paintline = @p1 and brandcode = @p2", new { p1 = line, p2 = brandCd }, tx).FirstOrDefault();
            return entity;
        }

        public List<PntLine> GetList(IPredicate pred, SqlTransaction tx = null)
        {
            return _db.Connection.GetList<PntLine>(pred, null, tx).OrderBy(x=>x.paintline).ThenBy(y=>y.brandcode).ToList();
        }

        public void Insert(PntLine entity, SqlTransaction tx = null)
        {
            _db.Insert(entity, tx);
        }

        public bool Update(PntLine entity, SqlTransaction tx = null)
        {
            return _db.Update(entity, tx);
        }

        public void Upsert(PntLine entity, SqlTransaction tx = null)
        {
            if (!Update(entity, tx))
                Insert(entity, tx);
        }

        public void Delete(PntLine entity, SqlTransaction tx = null)
        {
            _db.Delete(entity, tx);
        }
    }
}
