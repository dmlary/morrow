import api from "@/api/morrow";

export default {
  install: (Vue, options) => {
    const _morrow = api(options.url);

    Object.defineProperties(Vue.prototype, {
      $morrow: {
        get() {
          return _morrow;
        }
      }
    });
  }
};
