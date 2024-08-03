import React, { useState, memo } from "react";
import {
  Form,
  useLoaderData,
  redirect,
  useNavigate,
} from "react-router-dom";
import { updateContact } from "../contacts";

export async function action({ request, params }) {
  const formData = await request.formData();
  const updates = Object.fromEntries(formData);
  await updateContact(params.contactId, updates);
  return redirect(`/contacts/${params.contactId}`);
}

const EditContact = () => {
  const navigate = useNavigate();
  const { contact } = useLoaderData();
  const [genderFilter, setGenderFilter] = useState("all");

  const maleAvatars = [`/assets/images/avatars/avatar_male_default.png`, ...Array.from({ length: 10 }, (_, i) => `/assets/images/avatars/avatar_male_${String(i + 1).padStart(3, '0')}.png`)];
  const femaleAvatars = [`/assets/images/avatars/avatar_female_default.png`, ...Array.from({ length: 10 }, (_, i) => `/assets/images/avatars/avatar_female_${String(i + 1).padStart(3, '0')}.png`)];

  const getFilteredAvatars = () => {
    if (genderFilter === "male") {
      return maleAvatars;
    } else if (genderFilter === "female") {
      return femaleAvatars;
    } else {
      return [...maleAvatars, ...femaleAvatars];
    }
  };

  const getDefaultAvatar = () => {
    if (genderFilter === "male") {
      return "/assets/images/avatars/avatar_male_default.png";
    } else if (genderFilter === "female") {
      return "/assets/images/avatars/avatar_female_default.png";
    } else {
      return "";
    }
  };

  if (!contact) {
    return <p>Loading...</p>; // Handle case where contact is null
  }

  return (
    <Form method="post" id="contact-form">
      <p>
        <span>Name</span>
        <input
          placeholder="First"
          aria-label="First name"
          type="text"
          name="first"
          defaultValue={contact.first}
        />
        <input
          placeholder="Last"
          aria-label="Last name"
          type="text"
          name="last"
          defaultValue={contact.last}
        />
      </p>
      <label>
        <span>Twitter</span>
        <input
          type="text"
          name="twitter"
          placeholder="@jack"
          defaultValue={contact.twitter}
        />
      </label>
      <label>
        <span>Avatar Gender</span>
        <div>
          <label>
            <input
              id="avatar_gender_selector"
              type="radio"
              name="gender"
              value="all"
              checked={genderFilter === "all"}
              onChange={() => setGenderFilter("all")}
            />
            All
          </label>
          <label>
            <input
              id="avatar_gender_selector"
              type="radio"
              name="gender"
              value="male"
              checked={genderFilter === "male"}
              onChange={() => setGenderFilter("male")}
            />
            Male
          </label>
          <label>
            <input
              id="avatar_gender_selector"
              type="radio"
              name="gender"
              value="female"
              checked={genderFilter === "female"}
              onChange={() => setGenderFilter("female")}
            />
            Female
          </label>
        </div>
      </label>
      <label>
        <span>Avatar</span>
        <MemoizedAvatarOptions getFilteredAvatars={getFilteredAvatars} getDefaultAvatar={getDefaultAvatar} contact={contact} />
      </label>
      <label>
        <span>Notes</span>
        <textarea
          name="notes"
          defaultValue={contact.notes}
          rows={6}
        />
      </label>
      <p>
        <button type="submit">Save</button>
        <button
          type="button"
          onClick={() => {
            navigate(-1);
          }}
        >
          Cancel
        </button>
      </p>
    </Form>
  );
};

const AvatarOptions = ({ getFilteredAvatars, getDefaultAvatar, contact }) => {
  const filteredAvatars = getFilteredAvatars();
  const defaultAvatar = getDefaultAvatar();
  
  return (
    <select name="avatar" defaultValue={contact.avatar || defaultAvatar}>
      {filteredAvatars.map((url, index) => (
        <option key={index} value={url}>
          {url.split('/').pop()}
        </option>
      ))}
    </select>
  );
};

const MemoizedAvatarOptions = memo(AvatarOptions);

export default EditContact;