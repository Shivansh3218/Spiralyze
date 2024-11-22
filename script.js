// DOM Elements
const elements = {
  track: document.querySelector(".carousel-track"),
  slides: document.querySelectorAll(".testimonial"),
  prevButton: document.querySelector(".prev-button"),
  nextButton: document.querySelector(".next-button"),
  dots: document.querySelectorAll(".nav-dot"),
  videoPreview: document.querySelector(".video-preview"),
  modal: document.getElementById("videoModal"),
  closeButton: document.querySelector(".close-button"),
  playButton: document.querySelector(".play-button-hidden"),
  iframe: document.querySelector("iframe"),
};

// Carousel State
const carousel = {
  currentIndex: 0,
  slideWidth: 100, 
  touchStartX: 0,
  touchEndX: 0,

  updateDots(index) {
    elements.dots.forEach((dot) => dot.classList.remove("active"));
    elements.dots[index].classList.add("active");
  },

  moveToSlide(index) {
    if (index < 0) {
      index = elements.slides.length - 1;
    } else if (index >= elements.slides.length) {
      index = 0;
    }

    elements.track.style.transform = `translateX(-${index * this.slideWidth}%)`;
    this.currentIndex = index;
    this.updateDots(this.currentIndex);
  },
};

// Event Handlers
const handlers = {
  initCarouselControls() {
    elements.prevButton.addEventListener("click", () => {
      carousel.moveToSlide(carousel.currentIndex - 1);
    });

    elements.nextButton.addEventListener("click", () => {
      carousel.moveToSlide(carousel.currentIndex + 1);
    });

    elements.dots.forEach((dot, index) => {
      dot.addEventListener("click", () => carousel.moveToSlide(index));
    });
  },

  initTouchEvents() {
    elements.track.addEventListener("touchstart", (e) => {
      carousel.touchStartX = e.changedTouches[0].screenX;
    });

    elements.track.addEventListener("touchend", (e) => {
      carousel.touchEndX = e.changedTouches[0].screenX;
      const swipeDistance = 50;

      if (carousel.touchStartX - carousel.touchEndX > swipeDistance) {
        carousel.moveToSlide(carousel.currentIndex + 1);
      } else if (carousel.touchEndX - carousel.touchStartX > swipeDistance) {
        carousel.moveToSlide(carousel.currentIndex - 1);
      }
    });
  },

  initServiceCards() {
    document.querySelectorAll(".organize-service-card").forEach((card) => {
      const tooltip = card.querySelector(".tooltip");
      const tooltipText = card.getAttribute("data-tooltip");
      tooltip.textContent = tooltipText;

      card.addEventListener("mouseenter", () => {
        document
          .querySelectorAll(".tooltip")
          .forEach((t) => (t.style.display = "none"));
        tooltip.style.display = "block";
      });

      card.addEventListener("mouseleave", () => {
        tooltip.style.display = "none";
      });
    });
  },

  initHamburgerMenu() {
    const hamburger = document.querySelector(".hamburger");
    const navLinks = document.querySelector(".nav-links");

    hamburger.addEventListener("click", () => {
      hamburger.classList.toggle("active");
      navLinks.classList.toggle("active");
    });

    document.addEventListener("click", (e) => {
      if (!hamburger.contains(e.target) && !navLinks.contains(e.target)) {
        hamburger.classList.remove("active");
        navLinks.classList.remove("active");
      }
    });

    document.querySelectorAll(".nav-links a").forEach((link) => {
      link.addEventListener("click", () => {
        hamburger.classList.remove("active");
        navLinks.classList.remove("active");
      });
    });
  },

  initFormFields() {
    document
      .querySelectorAll(".form-field input, .form-field select")
      .forEach((input) => {
        input.addEventListener("focus", () => {
          const label = input.nextElementSibling;
          if (label) {
            label.textContent = input.placeholder || "Country";
          }
        });
      });
  },

  initVideoModal() {
    const closeModal = () => {
      elements.modal.style.display = "none";
      if (elements.iframe) {
        elements.iframe.src = "about:blank";
      }
    };

    elements.playButton.addEventListener("click", () => {
      elements.modal.style.display = "block";
    });

    elements.videoPreview.addEventListener("click", () => {
      elements.modal.style.display = "block";
      if (elements.iframe && videoUrl) {
        elements.iframe.src = videoUrl;
      }
    });

    elements.closeButton.addEventListener("click", closeModal);
    elements.modal.addEventListener("click", (e) => {
      if (e.target === elements.modal) closeModal();
    });
  },
};

// Initialize
document.addEventListener("DOMContentLoaded", () => {
  elements.track.style.transform = `translateX(0%)`;
  handlers.initCarouselControls();
  handlers.initTouchEvents();
  handlers.initServiceCards();
  handlers.initHamburgerMenu();
  handlers.initFormFields();
  handlers.initVideoModal();
});
