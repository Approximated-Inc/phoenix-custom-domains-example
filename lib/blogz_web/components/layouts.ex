defmodule BlogzWeb.Layouts do
  use BlogzWeb, :html

  embed_templates "layouts/*"
end

defmodule BlogzWeb.CustomDomainLayouts do
  use BlogzWeb, :html

  embed_templates "layouts/custom_domain/*"
end
