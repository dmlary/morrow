import axios from "axios";

export default url => {
  console.log("morrow", url);
  const client = axios.create({
    baseURL: url,
    json: true
  });

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
    },
    set_component_field(id, name, value) {
      return this.execute("put", `/component/${id}/${name}`, { value: value });
    }
  };
};
