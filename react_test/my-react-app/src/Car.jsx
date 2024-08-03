import React from 'react';

class Car extends React.Component {
  render() {
    return (
      <h2 style={{ color: "fuchsia", fontSize: "2.0rem"}}>
        A <span style={{ color: this.props.color, fontSize: "2.0rem", textTransform: "capitalize" }}>
          {this.props.year} {this.props.color} {this.props.brand} {this.props.model}
        </span> Super Car!
      </h2>
    );
  }
}

export default Car; 