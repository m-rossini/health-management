const path = require('path');
module.exports = {
  entry: {
    login: "./src/js/login.js", 
    register: "./src/js/register.js",
    main:    "./src/js/main.js",
  },
  devtool: 'source-map',
  mode: 'development',
  output: {
    filename: 'bundle.js',
    path: path.resolve(__dirname, 'dist'), // Output directory within public
    filename: '[name]Bundle.js',
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader', // Optional for transpilation
          options: {
            presets: ['@babel/preset-env'], // Configure Babel presets
          },
        },
      },
    ],
  },
};
