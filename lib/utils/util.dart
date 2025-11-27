String capitalizeWords(String name) {
  if (name.isEmpty) return "";

  return name
      .split(" ")
      .map(
        (word) => word
            .split(".")
            .map(
              (part) => part.isNotEmpty
                  ? part[0].toUpperCase() + part.substring(1).toLowerCase()
                  : "",
            )
            .join("."),
      )
      .join(" ");
}
