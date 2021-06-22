APP_INDEX ?= 0
BUILD_DIR = target

define object_for
$(addprefix $(BUILD_DIR)/,$(addsuffix .o,$(basename $(1))))
endef

src = $(addprefix src/,\
  alien.cpp \
  eadk.cpp \
  life.cpp \
  main.cpp \
  memcpy.cpp \
  memset.cpp \
  rocket.cpp \
  spaceship.cpp \
)

src += $(addprefix eadk/,\
  eadk.s \
)

SFLAGS = -I. -Wall -MD -MP -ggdb3 -mthumb -mfloat-abi=hard -mcpu=cortex-m7 -mfpu=fpv5-sp-d16 -Isrc
CPPFLAGS = -Os -std=c++11 -fdata-sections -ffunction-sections -fpie -fno-exceptions -ffreestanding -fno-rtti -nostdinc -nostdlib -fno-threadsafe-statics -Wno-narrowing
LFLAGS =  -Wl,--gc-sections -lgcc -Leadk -Wl,-T,eadk.ld

.PHONY: run
run: $(BUILD_DIR)/external_application.elf
	python3 eadk/run.py $^ --app-index $(APP_INDEX)

.PHONY: build
build: $(BUILD_DIR)/external_application.elf

$(BUILD_DIR)/external_application.elf: $(call object_for,$(src)) eadk/eadk.ld $(BUILD_DIR)/icon.ld
	arm-none-eabi-gcc $(LFLAGS) $(SFLAGS) $(filter-out %.ld,$^) -o $@

$(addprefix $(BUILD_DIR)/,%.o): %.cpp | $(BUILD_DIR)
	arm-none-eabi-g++ $(CPPFLAGS) $(SFLAGS) -c $^ -o $@

$(addprefix $(BUILD_DIR)/,%.o): %.s | $(BUILD_DIR)
	arm-none-eabi-as $(SFLAGS) -c $^ -o $@

.PRECIOUS: $(BUILD_DIR)/icon.ld
$(BUILD_DIR)/icon.ld: src/icon.png | $(BUILD_DIR)
	python3 eadk/inliner.py $< $@

.PRECIOUS: $(BUILD_DIR)
$(BUILD_DIR):
	$(Q) mkdir -p $@/src $@/eadk

.PHONY: clean
clean:
	@echo "CLEAN"
	$(Q) rm -rf $(BUILD_DIR)
