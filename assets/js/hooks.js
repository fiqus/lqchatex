function scrollBottom(el) {
  el.scrollTop = el.scrollHeight;
}

const hooks = {
  "new-chat-message": {
    mounted() {
      scrollBottom(this.el);
    },
    updated() {
      scrollBottom(this.el);
    }
  },
  "select-on-focus": {
    mounted() {
      this.el.onfocus = () => this.el.select();
      if (Array.from(this.el.classList).indexOf("select-on-show") > -1) {
        this.el.select();
      }
    }
  }
};

export default hooks
