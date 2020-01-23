import axios from "axios";

export default url => {
  const client = axios.create({ baseURL: url, json: true });

  return {
    async execute(method, path, data) {
      return client({
        method,
        url: path,
        data
      }).then(req => {
        return req.data;
      });
    },
    get_entity(id) {
      return this.execute("get", `/entity/${id}`);
    },
    get_entities(str) {
      return this.execute("get", `/entities?q=${str}`);
    }
  };
};
