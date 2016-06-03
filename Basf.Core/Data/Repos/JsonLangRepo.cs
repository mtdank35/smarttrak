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
    public class JsonLangRepo
    {
        private IDatabase _db;
        public JsonLangRepo(IDatabase db)
        {
            _db = db;
        }

        public JsonLang Get(int langId, SqlTransaction tx = null)
        {
            var entity = _db.Get<JsonLang>(new { LangId = langId }, tx);
            return entity;
        }

        public void Insert(JsonLang entity, SqlTransaction tx = null)
        {
            _db.Insert(entity, tx);
        }

        public bool Update(JsonLang entity, SqlTransaction tx = null)
        {
            return _db.Update(entity, tx);
        }

        public void Upsert(JsonLang entity, SqlTransaction tx = null)
        {
            if (!Update(entity, tx))
                Insert(entity, tx);
        }

        public void Delete(JsonLang entity, SqlTransaction tx = null)
        {
            _db.Delete(entity, tx);
        }
    }
}
