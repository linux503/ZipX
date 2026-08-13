document.querySelectorAll('a[href^="#"]').forEach((link) => {
  link.addEventListener("click", (event) => {
    const id = link.getAttribute("href");
    if (!id || id === "#") return;
    const target = document.querySelector(id);
    if (!target) return;
    event.preventDefault();
    target.scrollIntoView({ behavior: "smooth", block: "start" });
  });
});

const reveals = Array.prototype.slice.call(document.querySelectorAll(".reveal"));
const reduceMotion =
  window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;

function showAllReveals() {
  reveals.forEach(function (el) {
    el.classList.add("in");
  });
}

if (reduceMotion || !("IntersectionObserver" in window)) {
  showAllReveals();
} else {
  var io = new IntersectionObserver(
    function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add("in");
          io.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.12, rootMargin: "0px 0px -32px 0px" }
  );
  reveals.forEach(function (el) {
    io.observe(el);
  });

  // Safari 偶发首屏不触发：兜底显示
  setTimeout(function () {
    reveals.forEach(function (el) {
      if (!el.classList.contains("in")) {
        var rect = el.getBoundingClientRect();
        if (rect.top < window.innerHeight * 0.92) {
          el.classList.add("in");
        }
      }
    });
  }, 400);
}
