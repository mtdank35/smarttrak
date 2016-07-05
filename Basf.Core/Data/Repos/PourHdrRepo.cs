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
    public class PourHdrRepo
    {
        private IDatabase _db;
        public PourHdrRepo(IDatabase db)
        {
            _db = db;
        }

        public PourHdr Get(int pourId, SqlTransaction tx = null)
        {
            // someday, map appropriate primary keys to the db table and get them into the classmapper so dapper will automatically figure them out
            var entity = _db.Connection.Query<PourHdr>("SELECT * FROM pourhdr WHERE [id] = @p1", new { p1 = pourId }, tx).FirstOrDefault();
            return entity;
        }

        public List<PourHdr> GetList(IPredicate pred, SqlTransaction tx = null)
        {
            return _db.Connection.GetList<PourHdr>(pred, null, tx).ToList();
        }

        public void Insert(PourHdr entity, SqlTransaction tx = null)
        {
            _db.Insert(entity, tx);
        }

        public bool Update(PourHdr entity, SqlTransaction tx = null)
        {
            return _db.Update(entity, tx);
        }

        public void Upsert(PourHdr entity, SqlTransaction tx = null)
        {
            if (!Update(entity, tx))
                Insert(entity, tx);
        }

        public void Delete(PourHdr entity, SqlTransaction tx = null)
        {
            _db.Delete(entity, tx);
        }
    }
}
