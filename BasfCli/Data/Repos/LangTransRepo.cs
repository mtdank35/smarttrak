using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using Dapper;
using DapperExtensions;
using BasfCli.Data.Tables;
using DapperExtensions.Sql;
using DapperExtensions.Mapper;
using System.Reflection;

namespace BasfCli.Data.Repos
{
    public class LangTransRepo
    {
        private IDatabase _db;
        public LangTransRepo(IDatabase db)
        {
            _db = db;
        }

        public LangTrans Get(int langId, SqlTransaction tx = null)
        {
            var entity = _db.Get<LangTrans>(new { LangId = langId }, tx);
            return entity;
        }

        public List<LangTrans> GetList(int langId, SqlTransaction tx = null)
        {
            var pred = Predicates.Field<LangTrans>(x => x.lang_code, Operator.Eq, langId);
            return GetList(pred, tx);
        }

        public List<LangTrans> GetList(IPredicate pred, SqlTransaction tx = null)
        {
            return _db.Connection.GetList<LangTrans>(pred, null, tx).ToList();
        }

        public void Insert(LangTrans entity, SqlTransaction tx = null)
        {
            _db.Insert(entity, tx);
        }

        public bool Update(LangTrans entity, SqlTransaction tx = null)
        {
            return _db.Update(entity, tx);
        }

        public void Upsert(LangTrans entity, SqlTransaction tx = null)
        {
            if (!Update(entity, tx))
                Insert(entity, tx);
        }

        public void Delete(LangTrans entity, SqlTransaction tx = null)
        {
            _db.Delete(entity, tx);
        }
    }
}
