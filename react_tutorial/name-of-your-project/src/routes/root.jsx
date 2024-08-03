import {
  useEffect
} from "react";
import {
  Outlet,
  Link,
  NavLink,
  useLoaderData,
  Form,
  redirect,
  useNavigation,
  useSubmit,
} from "react-router-dom";
import { getContacts, createContact } from "../contacts";

export async function action() {
  const contact = await createContact();
  return redirect(`/contacts/${contact.id}/edit`);
}

export async function loader({ request }) {
  const url = new URL(request.url);
  const search = url.searchParams.get("search");
  const contacts = await getContacts(search);
  return { contacts, search };
}

export default function Root() {
  const { contacts, search } = useLoaderData();
  const navigation = useNavigation();
  const submit = useSubmit();

  const searching =
  navigation.location &&
  new URLSearchParams(navigation.location.search).has(
    "search"
  );

  useEffect(() => {
    document.getElementById("search").value = search;
  }, [search]);

  return (
    <>
      <div id="sidebar">
        <h1>React Router Contacts</h1>
        <div>
          <Form id="search-form" role="search">
            <input
              id="search"
              className={searching ? "loading" : ""}
              aria-label="Search contacts"
              placeholder="Search"
              type="search"
              name="search"
              defaultValue={search}
              onChange={(event) => {
                const isFirstSearch = search == null;
                submit(event.currentTarget.form, {
                  replace: !isFirstSearch,
                });
              }}
            />
            <div
              id="search-spinner"
              aria-hidden
              hidden={!searching}
            />
            <div
              className="sr-only"
              aria-live="polite"
            ></div>
          </Form>
          <Form method="post">
              <button type="submit">New</button>
          </Form>
        </div>
        <nav>
          {contacts.length ? (
            <ul>
              <li>
                <NavLink
                  to="/"
                  className={({ isActive, isPending }) =>
                    `home-page ${isActive ? "active" : isPending ? "pending" : ""}`
                  }
                >
                  Home
                </NavLink>
              </li>
              <h3>United Amigos —</h3>
              {contacts.map((contact) => (
                <li key={contact.id}>
                <NavLink
                    to={`contacts/${contact.id}`}
                    className={({ isActive, isPending }) =>
                      isActive
                        ? "active"
                        : isPending
                        ? "pending"
                        : ""
                    }
                  >
                    <Link to={`contacts/${contact.id}`}>
                      {contact.first || contact.last ? (
                        <>
                          {contact.first} {contact.last}
                        </>
                      ) : (
                        <i>No Name Yet</i>
                      )}{" "}
                      {contact.favorite && <span>★</span>}
                    </Link>
                  </NavLink>
                </li>
              ))}
            </ul>
          ) : (
            <p>
              <i>No contacts</i>
            </p>
          )}
        </nav>
      </div>
      <div id="detail"
        className={
          navigation.state === "loading" ? "loading" : ""
        }
      >
        <Outlet />
      </div>
    </>
  );
}