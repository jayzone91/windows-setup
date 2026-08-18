(() => {
    let applying = false;

    const getToolbarItem = (name) =>
        document.querySelector(`[data-name="${name}"]`)?.closest(".button-toolbar");

    const ensureGroup = (addressbar, className) => {
        let group = addressbar.querySelector(`:scope > .${className}`);

        if (!group) {
            group = document.createElement("div");
            group.className = className;
            addressbar.append(group);
        }

        return group;
    };

    const moveIfNeeded = (element, parent) => {
        if (element && element.parentElement !== parent) {
            parent.append(element);
        }
    };

    const applyLayout = () => {
        if (applying) {
            return;
        }

        applying = true;

        try {
            const browser = document.querySelector("#browser");
            const header = document.querySelector("#header");
            const main = document.querySelector("#main");
            const mainbar =
                main?.querySelector(":scope > .mainbar") ??
                browser?.querySelector(":scope > .mainbar");
            const addressbar = mainbar?.querySelector(".toolbar-addressbar");
            const addressField = addressbar?.querySelector('[data-name="AddressField"]');

            if (!browser || !header || !main || !mainbar || !addressbar || !addressField) {
                return;
            }

            getToolbarItem("AccountButton")?.remove();
            getToolbarItem("TabButton")?.remove();
            addressbar.querySelector(':scope > .button-toolbar.toolbar-spacer')?.remove();

            if (
                mainbar.parentElement !== browser ||
                mainbar.nextElementSibling !== header
            ) {
                browser.insertBefore(mainbar, header);
            }

            const left = ensureGroup(addressbar, "safari-toolbar-left");
            const center = ensureGroup(addressbar, "safari-toolbar-center");
            const right = ensureGroup(addressbar, "safari-toolbar-right");

            const windowButtons =
                document.querySelector(".window-buttongroup") ??
                left.querySelector(":scope > .window-buttongroup");

            const vivaldiButton =
                document.querySelector("#tabs-container > button.vivaldi") ??
                addressbar.querySelector(":scope > button.vivaldi") ??
                left.querySelector(":scope > button.vivaldi") ??
                right.querySelector(":scope > button.vivaldi");

            moveIfNeeded(windowButtons, left);

            if (windowButtons) {
                const close = windowButtons.querySelector(".window-close");
                const minimize = windowButtons.querySelector(".window-minimize");
                const maximize = windowButtons.querySelector(".window-maximize");

                if (
                    close &&
                    minimize &&
                    maximize &&
                    (
                        windowButtons.children[0] !== close ||
                        windowButtons.children[1] !== minimize ||
                        windowButtons.children[2] !== maximize
                    )
                ) {
                    windowButtons.replaceChildren(close, minimize, maximize);
                }
            }

            vivaldiButton?.querySelector(".expand-arrow")?.remove();
            moveIfNeeded(vivaldiButton, left);

            moveIfNeeded(getToolbarItem("Back"), left);
            moveIfNeeded(getToolbarItem("Forward"), left);
            moveIfNeeded(addressField, center);

            const reload = getToolbarItem("Reload");
            const addressFieldRightToolbar =
                addressField.querySelector(":scope > .toolbar.toolbar-insideinput:last-of-type");

            if (reload && addressFieldRightToolbar) {
                const bookmark = addressFieldRightToolbar.querySelector(".BookmarkButton");

                if (reload.parentElement !== addressFieldRightToolbar) {
                    addressFieldRightToolbar.insertBefore(reload, bookmark ?? null);
                }
            }

            moveIfNeeded(document.querySelector("#downloads"), right);
            moveIfNeeded(addressbar.querySelector(":scope > .toolbar-extensions"), right);
            moveIfNeeded(getToolbarItem("NewTab"), right);
        } finally {
            applying = false;
        }
    };

    const observer = new MutationObserver(applyLayout);

    observer.observe(document.documentElement, {
        childList: true,
        subtree: true
    });

    applyLayout();
})();