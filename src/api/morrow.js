import axios from "axios";

export default url => {
  const client = axios.create({
    baseURL: url,
    json: true
  });

  return {
    async execute(method, path, data) {
      return client({
        method,
        url: "/api/v1" + path,
        data
      }).then(req => {
        return req.data;
      });
    },
    get_entity(id) {
      return this.execute("get", `/entities/${id}`);
    },
    get_entities(str) {
      return this.execute("get", `/entities?q=${str}`);
    },
    get_component(id) {
      return this.execute("get", `/components/${id}`);
    },
    set_component_field(id, name, value) {
      return this.execute("put", `/components/${id}/${name}`, { value: value });
    }
  };
};
