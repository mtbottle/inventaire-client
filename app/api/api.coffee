module.exports = (_)->
  auth: require './auth'
  users: require './users'
  groups: require './groups'
  items: require './items'
  entities: require './entities'
  services: require './services'
  data: require './data'
  img: sharedLib('api/img')(_)
  comments:
    public: '/api/comments/public'
    private: '/api/comments'
  transactions: '/api/transactions'
  relations: '/api/relations'
  invitations: '/api/invitations'
  user: '/api/user'
  notifs: '/api/notifs'
  feedback: '/api/feedback/public'
  i18n: (lang)-> "/public/i18n/dist/#{lang}.json?DIGEST"
  moment: (lang)-> "/public/javascripts/moment/#{lang}.js?DIGEST"
  proxy: (url)-> "/api/proxy/public/#{url}"
  test: '/api/tests/public'
  scripts:
    pouchdb: '/public/javascripts/pouchdb-3.3.1.min.js'
  upload:
    post: '/api/upload'
    del: '/api/upload/delete'
