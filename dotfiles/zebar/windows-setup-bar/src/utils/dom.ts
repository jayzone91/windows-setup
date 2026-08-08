export function getElement<
  T extends HTMLElement = HTMLElement,
>(
  id: string,
): T {
  const element =
    document.getElementById(id);

  if (!element) {
    throw new Error(
      `Element '#${id}' wurde nicht gefunden.`,
    );
  }

  return element as T;
}
